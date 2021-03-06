! performs matrix-matrix multiply
! C=A*B
  subroutine mat_mul(nmatdim,A,B,C)
     
     use para, only : Dp
      implicit none


     integer,intent(in) :: nmatdim    

     complex(Dp) :: ALPHA
     complex(Dp) :: BETA 
 

     complex(Dp), intent(in)  :: A(nmatdim ,nmatdim)
     complex(Dp), intent(in)  :: B(nmatdim ,nmatdim)
     !complex(Dp) :: mat_mul(nmatdim,nmatdim)
     complex(Dp), intent(out) :: C(nmatdim,nmatdim)

     ALPHA=1.0d0 
     BETA=0.0D0

     C(:,:)=(0.0d0,0.0d0)

     call ZGEMM('N','N',nmatdim,nmatdim,nmatdim,ALPHA, &
               &  A,nmatdim,B,nmatdim,BETA,C,nmatdim)

     return
  end subroutine mat_mul

  !> ZGESVD computes the singular value decomposition (SVD) for GE matrices
  !> In this pack, we assume the matrix A is a square matrix, the dimension 
  !> of row and column are the same
  !> A = U * SIGMA * conjugate-transpose(V)
  !> VT= conjugate-transpose(V)
  subroutine zgesvd_pack(M, A, U, S, VT)

     use para, only : Dp
     implicit none

     integer, intent(in) :: M
     complex(dp), intent(inout) :: A(M, M)
     complex(dp), intent(out) :: U(M, M)
     real(dp)   , intent(out) :: S(M, M)
     complex(dp), intent(out) :: VT(M, M)

     character :: JOBU
     character :: JOBVT
     integer :: N
     integer :: LDA
     integer :: LDU
     integer :: LDVT
     integer :: LWORK
     complex(dp), allocatable :: WORK(:)
     real(dp), allocatable :: RWORK(:)
     integer :: INFO

     N= M
     LDA= M
     LDU= M
     LDVT= M
     allocate(RWORK(5*M))

     allocate(work(5*M))

     JOBU= 'A'
     JOBVT= 'A'

     LWORK = -1
     call zgesvd (JOBU, JOBVT, M, N, A, LDA, S, U, LDU, &
        VT, LDVT, WORK, LWORK, RWORK, INFO)
     if (INFO==0 .and. real(WORK(1))>0 )then
        LWORK= WORK(1)
        deallocate(work)
        allocate(WORK(LWORK))
     else
        write(*, *)'something wrong with zgesvd'
     endif


     call zgesvd (JOBU, JOBVT, M, N, A, LDA, S, U, LDU, &
        VT, LDVT, WORK, LWORK, RWORK, INFO)
     if (INFO /= 0) write(*, *)'something wrong with zgesvd'

     return
  end subroutine zgesvd_pack

  !============================================================!
  subroutine utility_diagonalize(mat,dim,eig,rot)
    !============================================================!
    !                                                            !
    ! Diagonalize the dim x dim  hermitian matrix 'mat' and      !
    ! return the eigenvalues 'eig' and the unitary rotation 'rot'!
    !                                                            !
    !============================================================!

    use para, only : dp, stdout

    integer, intent(in)           :: dim
    complex(kind=dp), intent(in)  :: mat(dim,dim)
    real(kind=dp), intent(out)    :: eig(dim)
    complex(kind=dp), intent(out) :: rot(dim,dim)

    complex(kind=dp), allocatable :: mat_pack(:),cwork(:)
    real(kind=dp), allocatable    :: rwork(:)
    integer            :: i,j,info,nfound
    integer, allocatable :: iwork(:),ifail(:)

    allocate(mat_pack((dim*(dim+1))/2))
    allocate(cwork(2*dim))
    allocate(rwork(7*dim))
    allocate(iwork(5*dim))
    allocate(ifail(dim))
    do j=1,dim
       do i=1,j
          mat_pack(i+((j-1)*j)/2)=mat(i,j)
       enddo
    enddo
    rot=0d0;eig=0.0_dp;cwork=0d0;rwork=0.0_dp;iwork=0
    call ZHPEVX('V','A','U',dim,mat_pack,0.0_dp,0.0_dp,0,0,-1.0_dp, &
         nfound,eig(1),rot,dim,cwork,rwork,iwork,ifail,info)
    if(info < 0) then
       write(stdout,'(a,i3,a)') 'THE ',-info,&
            ' ARGUMENT OF ZHPEVX HAD AN ILLEGAL VALUE'
       stop 'Error in utility_diagonalize'
    endif
    if(info > 0) then
       write(stdout,'(i3,a)') info,' EIGENVECTORS FAILED TO CONVERGE'
       stop 'Error in utility_diagonalize'
    endif

    return
  end subroutine utility_diagonalize

 
